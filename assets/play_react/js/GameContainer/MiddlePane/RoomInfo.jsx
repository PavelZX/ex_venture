import React from 'react';
import styled, { css } from 'styled-components';
import { connect } from 'react-redux';
import VmlToJsx from '../../SharedComponents/VmlToJsx.jsx';
import { theme } from '../../theme.js';

const Centered = styled.div`
  display: flex;
  justify-content: center;
`;

const RoomName = styled.div`
  display: flex;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
`;

const Exit = styled.span`
  color: white;
  cursor: pointer;
`;

const ColoredSpan = styled.span`
  color: ${props => props.color};
`;

const RoomInfo = ({ className, roomInfo }) => {
  console.log('roomInfo', roomInfo);
  const { name, description, players, npcs, shops, items, exits } = roomInfo;
  console.log('players', players);
  return (
    <div className={className}>
      <br />
      <RoomName>{name}</RoomName>
      <br />
      <br />
      <VmlToJsx vmlString={description} />
      <br />
      <br />
      <div>
        {players.map(player => (
          <VmlToJsx vmlString={player.status_line} />
        ))}
        {'  '}
        {npcs.map(npc => (
          <VmlToJsx vmlString={npc.status_line} />
        ))}{' '}
        {'  '}
        {shops.map(shop => (
          <VmlToJsx vmlString={shop.name} />
        ))}
        {'  '}
        {/* Items in the Room.Info GMCP module are not VML tagged so we need to manually color them here. */}
        {items.map((item, idx, itemsArr) => (
          <ColoredSpan color={theme.vml.item} key={item.id}>
            {item.name}
            {idx === itemsArr.length - 1 ? (
              <ColoredSpan color={theme.text}>. </ColoredSpan>
            ) : (
              <ColoredSpan color={theme.text}>, </ColoredSpan>
            )}
          </ColoredSpan>
        ))}{' '}
      </div>
      <br />
      <Centered>
        {exits ? 'You can leave: ' : null}
        {exits
          ? exits.map((exit, idx, exitsArr) => (
              <Exit
                onClick={() => {
                  send(exit.direction);
                }}
                style={{ color: 'white' }}
                key={exit.room_id}
              >
                {exit.direction}
                {idx === exitsArr.length - 1 ? (
                  <span style={{ color: '#c4e9e9' }}>. </span>
                ) : (
                  <span style={{ color: '#c4e9e9' }}>, </span>
                )}
              </Exit>
            ))
          : null}
      </Centered>
      <br />
    </div>
  );
};

RoomInfo.defaultProps = {
  roomInfo: {
    name: '',
    description: '',
    players: [],
    npcs: [],
    shops: [],
    items: [],
    exits: []
  }
};

const mapStateToProps = state => {
  return { roomInfo: state.roomInfo };
};

export default connect(mapStateToProps)(styled(RoomInfo)`
  padding: 1em 2em 1em 2em;
`);
